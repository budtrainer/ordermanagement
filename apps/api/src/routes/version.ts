import type { FastifyInstance } from 'fastify';

export async function versionRoutes(app: FastifyInstance) {
  app.get('/version', async (_req, reply) => {
    const payload = {
      app: '@budtrainer/api',
      version: process.env.APP_VERSION ?? '0.1.0',
      node: process.version,
      env: process.env.NODE_ENV ?? 'development',
      time: new Date().toISOString(),
    } as const;

    return reply.code(200).send(payload);
  });
}
