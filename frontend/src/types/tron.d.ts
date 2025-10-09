declare module 'tronweb' {
  const TronWeb: any;
  export default TronWeb;
}

declare global {
  interface Window {
    tronWeb?: any;
    tronLink?: any;
  }
}

export {};


