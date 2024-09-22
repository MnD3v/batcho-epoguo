import { motion } from 'framer-motion'
import React from 'react'
import Animations from './utils/item'
import { formations_neuf, formations_six, } from '../constants'

const Services = () => {


    return (
        <section id="formations" className='my-10 mx-2 md:mx-4 flex flex-col items-center'>

            <div className='max w-full font-jost pb-4'>
                <div className='flex items-center  self-start gap-2'>
                    <div className='h-2 w-2 bg-orange-600'></div>

                    <p className='text-orange-600 uppercase font-poppins font-bold'>Services</p>
                    <div className='h-2 w-2 bg-orange-600'></div>

                </div>
                <h1 className=' uppercase font-jost  font-semibold text-2xl md:text-4xl
            my-4
            self-start
            '>formations</h1>

                <h3>Nous offrons des formations modulaires de 9 et 6 mois</h3>
                <h2 className='inline-block text-lg md:text-xl  text-white font-bricolage
                my-6
                bg-orange-500 border-2 border-white rounded-full px-4 py-2
                ring ring-orange-500 self-start
                '>6 mois</h2>
            </div>
            <div className='max  grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3'>
                {
                    formations_six.map((element1) => {
                        const height = Math.random() * 300
                        const width = Math.random() * 100
                        return (
                            <motion.a
                                variants={Animations.bottomToTop({ duration: 0.3 * formations_six.indexOf(element1) + 0.2 })}
                                initial="hidden"
                                whileInView="show"
                                viewport={{ once: true }}
                                key={element1.image} href={"/formations/" + element1.link}> <div

                                    className='relative hover:text-white focus:text-white 
                                    h-full
                                    hover:bg-orange-950  focus:bg-orange-950 border border-orange-300 rounded-xl  
                                    p-4 transition-all duration-200
                                    overflow-hidden
                                    '>
                                    <div
                                        style={{ height: `${height}px`, width: `${height}px`, top: `${width}px`, left: `${width}px` }}
                                        className={"absolute bg-gradient-to-br from-orange-500/20 to-transparent rounded-full"}></div>
                                    <div className='relative  space-y-2 z-10'>
                                        <h3 className='font-semibold font-bricolage'>{element1.title}</h3>
                                        <p>{element1.description}</p>
                                        <h3 className='font-bricolage text-orange-800'>{element1.cost}</h3>
                                        <button className='font-bold text-orange-600 '>
                                            <div className='flex items-center'>
                                                <p>Voir plus</p>
                                                <img src="/icons/arrow-go.png" alt="" className='h-6' />
                                            </div>
                                        </button>
                                    </div>
                                </div>
                            </motion.a>
                        )
                    })
                }
            </div>
            <div className='max w-full'>

                <h2 className='inline-block text-lg md:text-xl text-white font-bricolage
                my-6 mt-12
                bg-orange-500 border-2 border-white rounded-full px-4 py-2
                ring ring-orange-500
                '>9 mois</h2>
            </div>

            <div className='max  grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3'>
                {
                    formations_neuf.map((element) => (
                        <motion.a
                            variants={Animations.bottomToTop({ duration: 0.3 * formations_neuf.indexOf(element) + 0.2 })}
                            initial="hidden"
                            whileInView="show"
                            viewport={{ once: true }}
                            key={element.image} href={"/formations/" + element.link}> <div

                                className='hover:text-white focus:text-white 
                                h-full
                                hover:bg-orange-950  focus:bg-orange-950 border border-orange-300 rounded-xl  
                                space-y-2 p-4 transition-all duration-200'>
                                <h3 className='font-semibold font-bricolage'>{element.title}</h3>
                                <p>{element.description}</p>
                                <h3 className='font-bricolage text-orange-800'>{element.cost}</h3>
                                <button className='font-bold text-orange-600 '>
                                    <div className='flex items-center'>
                                        <p>Voir plus</p>
                                        <img src="/icons/arrow-go.png" alt="" className='h-6' />
                                    </div>
                                </button>
                            </div>
                        </motion.a>
                    ))
                }
            </div>
        </section>
    )
}

export default Services