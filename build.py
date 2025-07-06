"""
Typst Notes 构建脚本
使用 shiroa 构建多个笔记本并生成统一的书架页面
支持 GitHub Pages 部署
"""

import os
import subprocess
import shutil
import json
from pathlib import Path
from datetime import datetime

class NotesBuilder:
    def __init__(self, root_dir=".", base_url=None):
        self.root_dir = Path(root_dir).resolve()
        self.notes_dir = self.root_dir / "notes"
        self.build_dir = self.root_dir / "build"
        self.static_dir = self.root_dir / "static"
        
        # 根据环境自动设置 BASE_URL
        if base_url is None:
            # 检查是否在 GitHub Actions 环境中
            if os.getenv('GITHUB_ACTIONS') == 'true':
                github_repository = os.getenv('GITHUB_REPOSITORY', '')
                if github_repository:
                    repo_name = github_repository.split('/')[-1]
                    self.base_url = f'/{repo_name}/'
                else:
                    self.base_url = '/'
            else:
                self.base_url = '/'
        else:
            self.base_url = base_url
            
        print(f"🔧 BASE_URL 设置为: {self.base_url}")

    def clean_build(self):
        """清理构建目录"""
        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)
        self.build_dir.mkdir(parents=True, exist_ok=True)
        print("✅ 构建目录已清理")

    def get_directory_last_modified(self, directory_path):
        """获取目录中所有文件的最后修改时间"""
        directory = Path(directory_path)
        if not directory.exists():
            return datetime.now()
        
        latest_time = 0
        # 遍历目录中的所有文件
        for file_path in directory.rglob('*'):
            if file_path.is_file():
                # 跳过一些不相关的文件
                if file_path.suffix in ['.DS_Store'] or file_path.name.startswith('.'):
                    continue
                try:
                    file_mtime = file_path.stat().st_mtime
                    latest_time = max(latest_time, file_mtime)
                except (OSError, FileNotFoundError):
                    continue
        
        if latest_time == 0:
            # 如果没有找到任何文件，返回目录本身的修改时间
            try:
                latest_time = directory.stat().st_mtime
            except (OSError, FileNotFoundError):
                return datetime.now()
        
        return datetime.fromtimestamp(latest_time)

    def find_notebooks(self):
        """发现所有笔记本"""
        notebooks = []
        if not self.notes_dir.exists():
            print("❌ notes 目录不存在")
            return notebooks

        for item in self.notes_dir.iterdir():
            if item.is_dir() and (item / "book.typ").exists():
                # 获取笔记本的实际最后修改时间
                last_modified = self.get_directory_last_modified(item)
                
                notebooks.append({
                    'name': item.name,
                    'path': str(item),
                    'relative_path': f"notes/{item.name}",
                    'book_file': str(item / "book.typ"),
                    'last_modified': last_modified
                })

        print(f"📚 发现 {len(notebooks)} 个笔记本: {[nb['name'] for nb in notebooks]}")
        return notebooks

    def build_notebook(self, notebook):
        """构建单个笔记本"""
        print(f"🔨 构建笔记本: {notebook['name']}")

        output_dir = self.build_dir / notebook['name']
        output_dir.mkdir(parents=True, exist_ok=True)

        try:
            # 使用正确的 base_url 路径
            notebook_base_url = self.base_url + notebook['name'] + "/"
            # notebook_base_url = "/" + notebook['name'] + "/"
            
            cmd = [
                "shiroa", "build",
                "--path-to-root", notebook_base_url,
                "-w", str(self.root_dir),
                notebook['path'],
                "--dest-dir", str(output_dir)
            ]
            
            print(f"🔧 执行命令: {' '.join(cmd)}")
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=self.root_dir
            )

            if result.returncode == 0:
                print(f"✅ {notebook['name']} 构建成功")
                return True
            else:
                stderr = result.stderr.strip()
                if "already exists" in stderr:
                    print(f"⚠️ {notebook['name']} 已存在构建输出，尝试清理后重试")
                    shutil.rmtree(output_dir)
                    return self.build_notebook(notebook)
                print(f"❌ {notebook['name']} 构建失败:")
                print(f"stdout: {result.stdout}")
                print(f"stderr: {stderr}")
                return False

        except subprocess.CalledProcessError as e:
            print(f"❌ 构建 {notebook['name']} 时出错: {e}")
            return False
        except FileNotFoundError:
            print("❌ 未找到 shiroa 命令，请确认已正确安装")
            return False

    def copy_static_files(self):
        """复制静态文件"""
        if self.static_dir.exists():
            dest_static = self.build_dir / "static"
            shutil.copytree(self.static_dir, dest_static, dirs_exist_ok=True)
            print("✅ 静态文件已复制")

    def copy_index_page(self):
        """复制首页文件并处理路径"""
        index_file = self.root_dir / "index.html"
        if index_file.exists():
            # 读取 index.html 内容
            with open(index_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 如果需要，可以在这里替换路径
            # 例如：content = content.replace('href="/', f'href="{self.base_url}')
            
            # 写入构建目录
            with open(self.build_dir / "index.html", 'w', encoding='utf-8') as f:
                f.write(content)
            
            print("✅ 首页文件已复制")
        else:
            print("⚠️  未找到 index.html，将跳过")

    def generate_notebook_manifest(self, notebooks):
        """生成笔记本清单"""
        manifest = {
            'generated_at': datetime.now().isoformat(),
            'base_url': self.base_url,
            'notebooks': []
        }

        for nb in notebooks:
            # 使用实际的最后修改时间，而不是构建时间
            manifest['notebooks'].append({
                'name': nb['name'],
                'title': nb['name'].replace('-', ' ').title(),
                'path': nb['name'],
                'url': self.base_url + nb['name'] + '/',
                'last_modified': nb['last_modified'].isoformat()
            })

        manifest_file = self.build_dir / "manifest.json"
        with open(manifest_file, 'w', encoding='utf-8') as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)

        print("✅ 笔记本清单已生成")

    def create_nojekyll(self):
        """创建 .nojekyll 文件以确保 GitHub Pages 正确处理文件"""
        nojekyll_file = self.build_dir / ".nojekyll"
        nojekyll_file.touch()
        print("✅ .nojekyll 文件已创建")

    def build_all(self):
        """构建所有笔记本"""
        print("🚀 开始构建 Typst Notes 项目")
        print("=" * 50)

        self.clean_build()
        notebooks = self.find_notebooks()
        if not notebooks:
            print("❌ 未发现任何笔记本，请检查 notes 目录")
            return False

        success_count = 0
        for notebook in notebooks:
            if self.build_notebook(notebook):
                success_count += 1

        self.copy_static_files()
        self.copy_index_page()
        self.generate_notebook_manifest(notebooks)
        self.create_nojekyll()

        print("=" * 50)
        print(f"🎉 构建完成! 成功构建 {success_count}/{len(notebooks)} 个笔记本")
        print(f"📁 输出目录: {self.build_dir}")
        
        if os.getenv('GITHUB_ACTIONS') != 'true':
            print(f"🌐 在浏览器中打开 {self.build_dir}/index.html 查看结果")

        return success_count == len(notebooks)

    def serve(self, port=8000):
        """启动本地服务器"""
        if not self.build_dir.exists():
            print("❌ 构建目录不存在，请先运行构建命令")
            return

        try:
            print(f"🌐 启动本地服务器，端口: {port}")
            print(f"📖 在浏览器中访问: http://localhost:{port}")

            subprocess.run([
                "python", "-m", "http.server", str(port)
            ], cwd=self.build_dir)

        except KeyboardInterrupt:
            print("\n👋 服务器已停止")


def main():
    import argparse

    parser = argparse.ArgumentParser(description="构建 Typst Notes 项目")
    parser.add_argument("command", choices=["build", "serve", "clean"], help="执行的命令")
    parser.add_argument("--port", type=int, default=8000, help="服务器端口 (默认: 8000)")
    parser.add_argument("--base-url", type=str, help="设置 BASE_URL (例如: /my-repo/)")

    args = parser.parse_args()
    builder = NotesBuilder(base_url=args.base_url)

    if args.command == "build":
        success = builder.build_all()
        if not success:
            exit(1)
    elif args.command == "serve":
        builder.build_all()
        builder.serve(args.port)
    elif args.command == "clean":
        builder.clean_build()
        print("✅ 构建目录已清理")

if __name__ == "__main__":
    main()