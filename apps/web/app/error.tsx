'use client';

import { useEffect } from 'react';

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  useEffect(() => {
    // Optionally log to an error reporting service
    // console.error(error);
  }, [error]);

  return (
    <main className="p-6">
      <h2 className="text-red-600 font-semibold text-xl">Something went wrong</h2>
      <button onClick={() => reset()} className="mt-4 rounded bg-blue-600 text-white px-3 py-2">
        Try again
      </button>
    </main>
  );
}
