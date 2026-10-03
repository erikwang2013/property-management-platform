// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 权限树勾选弹窗：拉 GET /admin/permission（树），勾选后把 hashid 数组回传给调用方。
// 只被角色页使用，故与角色页同目录，不放进通用 components。
import { Component, OnInit, inject, signal } from '@angular/core';
import { NzAlertModule } from 'ng-zorro-antd/alert';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzModalModule, NzModalRef } from 'ng-zorro-antd/modal';
import { NzSpinModule } from 'ng-zorro-antd/spin';
import { NZ_MODAL_DATA } from 'ng-zorro-antd/modal';
import { NzTreeModule, NzTreeNodeOptions } from 'ng-zorro-antd/tree';
import { firstValueFrom } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import { PERMISSION_TYPE } from '../../api/dict';

/** GET /admin/permission 的节点（id 已 hashid 编码，parent_id 保留为数字） */
export interface PermissionNode {
  id: string;
  name: string;
  slug: string;
  type: number;
  path: string;
  children?: PermissionNode[];
}

export interface PermissionModalData {
  roleId: string;
  roleName: string;
}

@Component({
  selector: 'xz-permission-modal',
  imports: [NzAlertModule, NzButtonModule, NzModalModule, NzSpinModule, NzTreeModule],
  template: `
    <nz-alert
      nzType="info"
      nzShowIcon
      nzMessage="勾选即全量覆盖该角色的权限"
      nzDescription="后端 GET /admin/role 不返回已授权限，因此本弹窗无法回显当前授权；未重新勾选即保存会清空原有授权。"
    />
    @if (loading()) {
      <div class="loading"><nz-spin nzSimple /></div>
    } @else if (error()) {
      <nz-alert nzType="error" nzShowIcon [nzMessage]="error()" />
    } @else {
      <nz-tree
        class="tree"
        [nzData]="nodes()"
        nzCheckable
        nzBlockNode
        nzExpandAll
        (nzCheckboxChange)="onCheck($event.keys)"
      />
      <div class="picked xz-muted">已选 {{ checked().length }} 项</div>
    }
    <div class="footer">
      <button nz-button (click)="ref.close(null)">取消</button>
      <button nz-button nzType="primary" [disabled]="!!error()" (click)="ref.close(checked())">
        保存授权
      </button>
    </div>
  `,
  styles: [
    `
      .tree {
        max-height: 52vh;
        margin-top: 12px;
        overflow: auto;
      }
      .loading {
        padding: 32px 0;
        text-align: center;
      }
      .picked {
        margin-top: 8px;
        font-size: 12px;
      }
      .footer {
        display: flex;
        justify-content: flex-end;
        gap: 8px;
        margin-top: 16px;
      }
    `,
  ],
})
export class PermissionModalComponent implements OnInit {
  protected readonly ref = inject<NzModalRef<PermissionModalComponent, string[] | null>>(NzModalRef);
  private readonly api = inject(ApiService);
  protected readonly data = inject<PermissionModalData>(NZ_MODAL_DATA);

  protected readonly loading = signal(true);
  protected readonly error = signal('');
  protected readonly nodes = signal<NzTreeNodeOptions[]>([]);
  protected readonly checked = signal<string[]>([]);

  ngOnInit(): void {
    this.api.get<PermissionNode[]>(API.permission).subscribe({
      next: (tree) => {
        this.nodes.set(tree.map((n) => this.toNode(n)));
        this.loading.set(false);
      },
      error: (err: unknown) => {
        this.loading.set(false);
        this.error.set(errorText(err));
      },
    });
  }

  private toNode(node: PermissionNode): NzTreeNodeOptions {
    const kind = PERMISSION_TYPE[Number(node.type)] ?? '';
    const label = kind ? `${node.name}（${kind}）` : node.name;
    return {
      title: node.slug ? `${label} · ${node.slug}` : label,
      key: node.id,
      isLeaf: !node.children?.length,
      children: node.children?.map((c) => this.toNode(c)),
    };
  }

  protected onCheck(keys: string[] | undefined): void {
    this.checked.set(keys ?? []);
  }
}
