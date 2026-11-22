import { HttpClient } from '@angular/common/http';
import { Component, inject, OnInit, signal } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  private readonly http = inject(HttpClient);
  protected readonly commitId = signal<string | null>(null);
  protected readonly statusFailed = signal(false);

  ngOnInit(): void {
    this.http.get<{ commitId: string }>('/api/status').subscribe({
      next: ({ commitId }) => this.commitId.set(commitId),
      error: () => this.statusFailed.set(true),
    });
  }
}
