import './globals.css';

import type { ReactNode } from 'react';
import { Toaster } from 'react-hot-toast';

import Providers from './providers';

export const metadata = {
  title: 'Budtrainer',
  description: 'Order Management & Supplier Portal',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>
          {children}
          <Toaster position="top-right" />
        </Providers>
      </body>
    </html>
  );
}
