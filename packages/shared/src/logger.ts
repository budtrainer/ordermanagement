export type LogLevel = 'info' | 'warn' | 'error' | 'debug';
export type LogContext = Record<string, unknown>;
export type LogSink = (level: LogLevel, message: string, context?: LogContext) => void;

export class StructuredLogger {
  constructor(
    private readonly sink: LogSink,
    private readonly service?: string,
  ) {}

  info(message: string, context: LogContext = {}): void {
    this.log('info', message, context);
  }

  warn(message: string, context: LogContext = {}): void {
    this.log('warn', message, context);
  }

  error(message: string, context: LogContext = {}): void {
    this.log('error', message, context);
  }

  debug(message: string, context: LogContext = {}): void {
    this.log('debug', message, context);
  }

  private log(level: LogLevel, message: string, context: LogContext): void {
    const entry = {
      level,
      message,
      timestamp: new Date().toISOString(),
      service: this.service,
      ...context,
    };
    this.sink(level, message, entry);
  }
}
