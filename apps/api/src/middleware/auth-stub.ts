import type {
  FastifyInstance,
  FastifyReply,
  FastifyRequest,
  HookHandlerDoneFunction,
} from 'fastify';

/**
 * Minimal auth stub: logs presence of Authorization header and continues.
 * Prepara o terreno para RBAC (F1.2) sem bloquear requests neste momento.
 */
export function registerAuthStub(app: FastifyInstance) {
  app.addHook(
    'preHandler',
    (request: FastifyRequest, _reply: FastifyReply, done: HookHandlerDoneFunction) => {
      const hasAuth = Boolean(request.headers.authorization);
      request.log.debug({ hasAuth }, 'Auth stub');
      done();
    },
  );
}
