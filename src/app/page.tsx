import Image from 'next/image';

export default function Page() {
  return (
    <main>
      <h1>IQSF Agent Dashboard</h1>
      <Image src="/images/brand-logo.png" alt="IQSF Logo" width={240} height={240} />
      {/* Other dashboard content goes here */}
    </main>
  );
}
