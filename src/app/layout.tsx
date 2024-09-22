import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";
import { GlobalStateProvider } from "./contexts/GlobalStateContext";

const geistSans = localFont({
  src: "./fonts/GeistVF.woff",
  variable: "--font-geist-sans",
  weight: "100 900",
});
const geistMono = localFont({
  src: "./fonts/GeistMonoVF.woff",
  variable: "--font-geist-mono",
  weight: "100 900",
});

export const metadata: Metadata = {
  title: "Institut Batcho&Epoguo",
  description: "Entreprise de formation des jeunes",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {

  const socials = [{ icon: "facebook.png", link: "" },
  { icon: "linkedin.png", link: "" },
  { icon: "twitter.png", link: "" },
  { icon: "youtube.png", link: "" },

  ]
  return (
    <html lang="en">
      <head>
        <link href="https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&family=Syne:wght@400..800&display=swap" rel="stylesheet" />
        <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400..800&display=swap" rel="stylesheet" />
        <link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,200..800&display=swap" rel="stylesheet"></link>
        <link href="https://fonts.googleapis.com/css2?family=Jost:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet"></link>
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <GlobalStateProvider>
          {children}
        </GlobalStateProvider>

        <footer className="relative flex justify-center bg-orange-950 p-9 pt-9 md:pt-24 text-white overflow-hidden max-sm:text-sm">
          <div className="absolute 
          -bottom-12 -left-[50%]
          h-full w-full
         bg-gradient-to-bl from-white/10 to-transparent 
          -rotate-45
           z-0 "></div>
          <div className="relative z-10 max flex flex-wrap justify-center gap-9">

            <div>
              <img src="/black-logo.png" alt="" className="h-12 md:h-20" />
              <p className="w-80 mt-1">Chez batcho-Group,offre des solutions sur mesure pour donner vie à vos projets avec efficacité et innovation.</p>
              <div className="my-6 flex gap-2">
                {socials.map((element) => (
                  <div key={element.icon} className="bg-white h-14 w-14 rounded-lg flex flex-col items-center justify-center">
                    <img src={`/icons/${element.icon}`} alt="" className="h-6" />
                  </div>
                ))}
              </div>
            </div>
            <div className="pt-6 w-80">
              <h3>
                Contact
              </h3>
              <div className="flex items-center">
                <img src="/icons/phone.png" alt="" className="h-6 " />
                <p className="p-3">+228 90559055</p>
              </div>
              <div className="flex items-center">
                <img src="/icons/mail.png" alt="" className="h-6 " />
                <p className="p-3">batcho-Group@gmail.com</p>
              </div>
              <div className="flex items-center">
                <img src="/icons/map.png" alt="" className="h-6 mx-1 " />
                <p className="p-3">Dongoyo, Kara-Togo</p>
              </div>
            </div>
            <div className="pt-6 w-80">
              <h3>Newletter</h3>
              <p className="my-3">Recevez les notifications concernant l'evolution de nos service et de nos articles</p>
              <input type="email" placeholder="Entrez votre mail" className="w-full bg-transparent border border-white/20 rounded-xl p-3" />
              <button className="bg-orange-600 w-full py-3 my-4 rounded-xl uppercase">S'abonner</button>
            </div>
          </div>

        </footer>
      </body>
    </html>
  );
}
