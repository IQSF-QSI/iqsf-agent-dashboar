import Image from 'next/image';

export default function BrandLogo() {
  return (
    <Image
      src="/IMG_0284.jpg"
      alt="IQSF Shield"
      width={120}
      height={120}
      style={{
        borderRadius: '12px',
        boxShadow: '0 0 12px #ff4fd8'
      }}
      priority
    />
  );
}
