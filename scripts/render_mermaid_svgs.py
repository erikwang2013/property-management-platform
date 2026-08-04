#!/usr/bin/env python3
"""Extract Mermaid code blocks from markdown files and render them to SVG via mermaid.ink."""
import re
import os
import base64
import urllib.request
import time
import json

DOCS_DIR = os.path.join(os.path.dirname(__file__), '..', 'docs')
IMAGES_DIR = os.path.join(DOCS_DIR, 'images')
ROOT_DIR = os.path.join(os.path.dirname(__file__), '..')

DIAGRAM_MAP = {
    'docs/ARCHITECTURE_DIAGRAM.md': [
        ('architecture_overview', '系统全景架构'),
        ('architecture_layered', '分层架构详图'),
        ('architecture_deployment', '部署架构'),
    ],
    'docs/FLOWCHART.md': [
        ('flow_auth', '用户认证流程'),
        ('flow_fee', '费用管理'),
        ('flow_repair', '报修处理流程'),
        ('flow_property', '房产管理流程'),
        ('flow_complaint', '投诉建议处理流程'),
        ('flow_visitor', '访客通行流程'),
    ],
    'docs/FUNCTION_DIAGRAM.md': [
        ('function_overview', '功能模块全景'),
        ('function_deps', '模块依赖关系'),
        ('function_admin_tree', '管理后台功能树'),
        ('function_owner_map', '业主端功能地图'),
    ],
    'docs/LIFECYCLE_DIAGRAM.md': [
        ('lifecycle_request', '请求生命周期'),
        ('lifecycle_owner', '数据实体生命周期 - 业主'),
        ('lifecycle_fee', '数据实体生命周期 - 费用账单'),
        ('lifecycle_repair', '数据实体生命周期 - 报修工单'),
        ('lifecycle_token', 'JWT Token 生命周期'),
        ('lifecycle_crud', '数据库记录完整生命周期'),
    ],
    'docs/SECURITY_ARCHITECTURE.md': [
        ('security_defense', '18层纵深防御全景'),
        ('security_request_chain', '请求安全处理链路'),
        ('security_encryption_chain', '数据加密全链路'),
        ('security_auth_model', '认证与授权模型'),
        ('security_attack_matrix', '攻击面防护矩阵'),
        ('security_audit', '审计追溯体系'),
    ],
}

README_DIAGRAMS = {
    'README.md': [
        ('readme_architecture', '系统全景架构'),
        ('readme_business_flow', '核心业务流程'),
        ('readme_modules', '功能模块总览'),
        ('readme_lifecycle', '数据实体生命周期'),
        ('readme_security', '18层安全纵深防御'),
    ],
    'README_EN.md': [
        ('readme_en_architecture', 'System Architecture Overview'),
        ('readme_en_business_flow', 'Core Business Flow'),
        ('readme_en_modules', 'Function Module Overview'),
        ('readme_en_lifecycle', 'Entity Lifecycle'),
        ('readme_en_security', '18-Layer Defense-in-Depth Security'),
    ],
}


def extract_mermaid_blocks(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    pattern = re.compile(r'```mermaid\n(.*?)```', re.DOTALL)
    blocks = []
    for m in pattern.finditer(content):
        code = m.group(1).strip()
        blocks.append(code)
    return blocks


def render_via_mermaid_ink(mermaid_code, output_path):
    """Use mermaid.ink API to render mermaid code to SVG."""
    # Encode mermaid code as base64 for mermaid.ink
    encoded = base64.urlsafe_b64encode(mermaid_code.encode('utf-8')).decode('ascii')
    url = f'https://mermaid.ink/svg/{encoded}'

    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=30) as resp:
            svg_data = resp.read()
            if not svg_data.strip():
                return False
            with open(output_path, 'wb') as f:
                f.write(svg_data)
            return True
    except Exception as e:
        print(f"ERROR: {e}")
        return False


def main():
    os.makedirs(IMAGES_DIR, exist_ok=True)
    all_files = {**DIAGRAM_MAP, **README_DIAGRAMS}
    total = sum(len(v) for v in all_files.values())
    success = 0
    fail = 0

    for rel_path, diagrams in all_files.items():
        filepath = os.path.join(ROOT_DIR, rel_path)
        if not os.path.exists(filepath):
            print(f"SKIP: {filepath}")
            continue
        blocks = extract_mermaid_blocks(filepath)
        print(f"\n{rel_path}: {len(blocks)} blocks, {len(diagrams)} expected")
        for i, (name, section_title) in enumerate(diagrams):
            if i >= len(blocks):
                print(f"  WARN: missing block {i} for '{name}' ({section_title})")
                fail += 1
                continue
            code = blocks[i]
            svg_path = os.path.join(IMAGES_DIR, f'{name}.svg')
            sys.stdout.write(f"  {name}.svg ... ")
            sys.stdout.flush()
            if render_via_mermaid_ink(code, svg_path):
                size = os.path.getsize(svg_path)
                print(f"OK ({size:,} bytes)")
                success += 1
            else:
                print("FAIL")
                fail += 1
            time.sleep(0.5)  # Rate limit

    print(f"\n{'='*50}")
    print(f"Done: {success} ok, {fail} fail, {total} total")


if __name__ == '__main__':
    import sys
    main()
