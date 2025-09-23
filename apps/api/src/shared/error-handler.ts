import type { FastifyError, FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { ZodError } from 'zod';

export function registerErrorHandler(app: FastifyInstance) {
  app.setErrorHandler(
    (error: FastifyError | Error, request: FastifyRequest, reply: FastifyReply) => {
      // Zod validation errors
      if (error instanceof ZodError) {
        request.log.warn({ err: error, issues: error.issues }, 'Validation error');
        return reply.status(400).send({
          error: 'validation_error',
          message: 'Invalid request',
          issues: error.issues,
          requestId: request.id,
        });
      }

      // Syntax errors (e.g., invalid JSON body)
      if ((error as Error).name === 'SyntaxError') {
        request.log.warn({ err: error }, 'Syntax error');
        return reply.status(400).send({
          error: 'bad_request',
          message: error.message,
          requestId: request.id,
        });
      }

      // Unknown errors
      request.log.error({ err: error }, 'Unhandled error');
      return reply.status(500).send({
        error: 'internal_error',
        message: 'Internal Server Error',
        requestId: request.id,
      });
    },
  );
}
