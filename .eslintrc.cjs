/* eslint-env node */
/**
 * Root ESLint config for Budtrainer monorepo
 */
module.exports = {
  root: true,
  env: {
    es2022: true,
    node: true,
    browser: true,
  },
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint', 'import', 'simple-import-sort'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:import/recommended',
    'plugin:import/typescript',
    'prettier',
  ],
  settings: {
    'import/resolver': {
      typescript: {
        project: ['./tsconfig.base.json'],
      },
    },
  },
  rules: {
    // Typescript
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],

    // Imports
    'import/order': 'off',
    'simple-import-sort/imports': 'error',
    'simple-import-sort/exports': 'error',
    'import/newline-after-import': ['error', { count: 1 }],

    // General
    'no-console': ['warn', { allow: ['warn', 'error', 'info'] }],
  },
  ignorePatterns: ['**/dist/**', '**/build/**', '**/.next/**', '**/node_modules/**'],
  overrides: [
    {
      files: ['*.js', '*.cjs'],
      parser: 'espree',
    },
  ],
};
