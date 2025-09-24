export type MetricTags = Record<string, string | number | boolean | null | undefined>;
export type MetricSink = (name: string, value: number, tags?: MetricTags) => void;

export class MetricsCollector {
  constructor(
    private readonly sink: MetricSink,
    private readonly service?: string,
  ) {}

  increment(name: string, tags: MetricTags = {}): void {
    this.sink(this.qualify(name), 1, tags);
  }

  histogram(name: string, value: number, tags: MetricTags = {}): void {
    this.sink(this.qualify(name), value, tags);
  }

  private qualify(name: string): string {
    return this.service ? `${this.service}.${name}` : name;
  }
}
