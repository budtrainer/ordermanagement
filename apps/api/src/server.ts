import helmet from '@fastify/helmet';
import Fastify from 'fastify';

import type { LogContext, LogLevel, MetricTags } from '../../../packages/shared/src/index.js';
import { MetricsCollector, StructuredLogger } from '../../../packages/shared/src/index.js';
import { registerAuthStub } from './middleware/auth-stub.js';
import { healthRoutes } from './routes/health.js';
import { versionRoutes } from './routes/version.js';
import { registerErrorHandler } from './shared/error-handler.js';

const app = Fastify({
  logger: {
    level: process.env.LOG_LEVEL ?? 'info',
    transport:
      process.env.NODE_ENV !== 'production'
        ? {
            target: 'pino-pretty',
            options: { colorize: true, translateTime: 'SYS:standard' },
          }
        : undefined,
  },
});

// Structured logger and metrics (F1.0-J)
const structuredLogger = new StructuredLogger(
  (level: LogLevel, message: string, context?: LogContext) => {
    const contextData = context ?? {};
    switch (level) {
      case 'error':
        app.log.error(contextData, message);
        break;
      case 'warn':
        app.log.warn(contextData, message);
        break;
      case 'debug':
        app.log.debug(contextData, message);
        break;
      default:
        app.log.info(contextData, message);
    }
  },
  'api',
);

const metrics = new MetricsCollector((name: string, value: number, tags?: MetricTags) => {
  app.log.debug({ metric: name, value, ...(tags ?? {}) }, 'metric');
}, 'api');

// Security headers (F1.0-I)
// Disable CSP for API responses (not serving HTML). Other headers remain active.
await app.register(helmet, { contentSecurityPolicy: false });

// Auth stub (prepara RBAC na F1.2)
registerAuthStub(app);

// Global error handler (sempre por último)
registerErrorHandler(app);

// Routes
app.register(healthRoutes);
app.register(versionRoutes);

// Always include correlation id header
app.addHook('onSend', (request, reply, payload, done) => {
  reply.header('x-request-id', request.id);
  done();
});

// Measure and log request latency
interface RequestWithTiming {
  startAt?: number;
  routerPath?: string;
}

app.addHook('onRequest', (request, _reply, done) => {
  (request as RequestWithTiming).startAt = Date.now();
  done();
});

app.addHook('onResponse', (request, reply, done) => {
  const startAt = (request as RequestWithTiming).startAt;
  const durationMs = startAt ? Date.now() - startAt : 0;

  interface ReplyWithContext {
    context?: {
      config?: {
        url?: string;
      };
    };
  }

  const route =
    (reply as ReplyWithContext)?.context?.config?.url ??
    (request as RequestWithTiming).routerPath ??
    request.url;

  metrics.histogram('http.server.duration', durationMs, {
    route: String(route),
    method: request.method,
    status: reply.statusCode,
  });

  structuredLogger.info('request_completed', {
    requestId: request.id,
    method: request.method,
    url: request.url,
    route: String(route),
    statusCode: reply.statusCode,
    durationMs,
  });
  done();
});

// Start server only when executed directly (not during tests)
if (process.env.NODE_ENV !== 'test') {
  const PORT = Number(process.env.PORT) || 4000;
  const HOST = process.env.HOST || '0.0.0.0';

  app
    .listen({ port: PORT, host: HOST })
    .then((address: string) => app.log.info({ address }, 'API listening'))
    .catch((err: unknown) => {
      app.log.error({ err }, 'Failed to start server');
      process.exit(1);
    });
}

export type AppInstance = typeof app;
export default app;
