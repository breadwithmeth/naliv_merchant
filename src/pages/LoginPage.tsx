import { FormEvent, useState } from 'react';
import { KeyRound, LogIn } from 'lucide-react';
import { Navigate, useNavigate } from 'react-router-dom';
import { Button } from '../components/Button';
import { useAuthStore } from '../store/auth';
import { useToastStore } from '../store/toasts';

export function LoginPage() {
  const [token, setToken] = useState('');
  const [error, setError] = useState<string | null>(null);
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const login = useAuthStore((state) => state.login);
  const showToast = useToastStore((state) => state.showToast);
  const navigate = useNavigate();

  if (isAuthenticated) return <Navigate to="/" replace />;

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmed = token.trim();

    if (!trimmed) {
      setError('Введите токен');
      return;
    }

    login(trimmed);
    showToast({ type: 'success', title: 'Токен сохранен' });
    navigate('/', { replace: true });
  };

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50 px-4 py-8">
      <form
        onSubmit={submit}
        className="w-full max-w-md rounded-lg border border-line bg-white p-6 shadow-soft"
      >
        <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-brand-50 text-brand-700">
          <KeyRound className="h-6 w-6" />
        </div>
        <h1 className="mt-5 text-2xl font-bold text-ink">Вход в панель магазина</h1>
        <p className="mt-2 text-sm leading-6 text-muted">
          Введите Bearer token. Запрос авторизации не выполняется.
        </p>

        <label className="mt-6 block text-sm font-semibold text-ink" htmlFor="token">
          Bearer token
        </label>
        <input
          id="token"
          type="password"
          value={token}
          onChange={(event) => {
            setToken(event.target.value);
            setError(null);
          }}
          className="mt-2 w-full rounded-lg border border-line px-3 py-3 text-sm outline-none transition focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
          placeholder="Вставьте токен"
          autoComplete="off"
        />
        {error ? <p className="mt-2 text-sm text-red-600">{error}</p> : null}

        <Button type="submit" className="mt-6 w-full" icon={<LogIn className="h-4 w-4" />}>
          Войти
        </Button>
      </form>
    </main>
  );
}
