"use client"
import Services from "./components/services";
import APropos from "./components/apropos";
import Satisfaction from "./components/satisfaction";
import Amelioration from "./components/amelioration";
import Presentation from "./components/presentation";
import Contact from "./components/contact";
import Equipe from "./components/equipe";
import FixedAppBar from "./components/fixed_app_bar";
import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Animations from "./components/utils/item";

export default function Home() {
  const [isInView, setIsInView] = useState(true);

  useEffect(() => {

    setIsInView(false)

    return () => {

    }
  }, [])
  return (
    <div>
      {
        isInView && <div className='fixed flex flex-col items-center justify-center bg-orange-100 h-full w-full'>
          <div className='loader'></div>
        </div>}
      <motion.div
        variants={Animations.opacity({ duration: 0.9 })}
        initial="hidden"
        whileInView="show"
        className="bg-orange-50 text-orange-950">

        <FixedAppBar></FixedAppBar>
        <Presentation></Presentation>
        <Services></Services>
        <APropos></APropos>
        <Satisfaction></Satisfaction>
        <Amelioration></Amelioration>
        <Contact></Contact>
        <Equipe></Equipe>
      </motion.div>

      {/* <div className="fixed top-1/2 right-1/2 z-50 bg-green-600/30 backdrop-blur-lg p-4 text-white font-bold text-2xl">
        <div className="sm:hidden">SM</div>
        <div className="max-sm:hidden md:hidden">MD</div>
        <div className="max-md:hidden lg:hidden">LG</div>
        <div className="max-lg:hidden xl:hidden">XL</div>
        <div className="max-xl:hidden 2xl:hidden">2XL</div>
        <div className="max-2xl:hidden 32xl:hidden">3XL</div>
      </div> */}
    </div>

  );
}
