import { useEffect } from 'react';
import { useRouter } from 'next/router';

// Instantly redirect / to /dashboard
export default function Home() {
  const router = useRouter();
  useEffect(() => { router.replace('/dashboard'); }, [router]);
  return null;
}
