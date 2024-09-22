import React from 'react'
import AppBar from './app_bar'
import { motion } from 'framer-motion'
import Animations from './utils/item'

const Presentation = () => {
    return (
        <section id='' className="relative flex justify-center bg-cover overflow-hidden">
            <div className='w-full flex justify-center bg-orange-100'>
                <div
                    style={{
                        backgroundImage: "radial-gradient(#fb923c 1px, transparent 0)",
                        backgroundSize: "20px 20px"
                    }}
                    className='w-full flex flex-col items-center text-orange-900'>
                    <AppBar></AppBar>
                    <div

                        className='max w-full flex max-lg:flex-col max-lg:items-center md:justify-between'>
                        <div className=' p-6 space-y-5 md:space-y-10'>
                            <div className="max space-y-3">
                                <motion.h1
                                    variants={Animations.bottomToTop({ duration: 0.7 })}
                                    initial="hidden"
                                    whileInView="show"
                                    className="capitalize leading-relaxed text-3xl md:text-4xl lg:text-5xl font-bold font-jost">Faites vous former par l'Institut <span className='text-orange-700'>Batcho&Epoguo</span>  dans les  <motion.span className='text-orange-700'>Metiers de l'Avenir</motion.span> </motion.h1>

                            </div>
                            <div className=" max flex  flex-wrap max-sm:flex-wrap">
                                <motion.p
                                    variants={Animations.bottomToTop({ duration: 2.2 })}
                                    initial="hidden"
                                    whileInView="show"
                                    className="max-w-[400px]">
                                    Transformez vos ambitions en compétences digitales grâce à nos formations, pour réussir dans un monde en pleine transformation.
                                </motion.p>
                                <motion.a href='#formations'
                                    variants={Animations.scale({ duration: 2.5 })}
                                    initial="hidden"
                                    whileInView="show"
                                    className=" text-orange-800 hover:text-white uppercase font-semibold
                                    px-10 py-4 my-3
                                    hover:bg-orange-800 border-2 border-orange-800 rounded-tl-3xl rounded-br-3xl
                                     ">nos formations
                                </motion.a>
                            </div>
                        </div>
                        <motion.img
                            variants={Animations.leftToRight({ duration: 0.9, inverse: true })}
                            initial="hidden"
                            whileInView="show"
                            src="/etudiante.png" alt="" className='h-[400px] ' />
                    </div>

                </div>
            </div>
        </section>
    )
}

export default Presentation