import Fastify from 'fastify';

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

// Auth stub (prepara RBAC na F1.2)
registerAuthStub(app);

// Global error handler (sempre por último)
registerErrorHandler(app);

// Routes
app.register(healthRoutes);
app.register(versionRoutes);

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
