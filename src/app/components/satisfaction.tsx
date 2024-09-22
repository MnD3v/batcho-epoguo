import { motion } from 'framer-motion'
import React from 'react'
import Animations from './utils/item'

const Satisfaction = () => {

    const chiffres = [
        { titre: "750", subtitre: "Jeunes", description: " ont bénéficié de programmes de formation et d'accompagnement professionnel" },
        { titre: "6", subtitre: "ans", description: " d'impact et de croissance continue dans l'accompagnement des jeunes" },
        { titre: "98", subtitre: "%", description: "de satisfaction de nos clients devient 98% de nos clients se déclarent pleinement satisfaits des services et des résultats obtenus" },
    ]
    return (
        <div className='  bg-orange-800 object-cover my-10 '>
            <div className='text-white flex   justify-center  w-full h-full py-6 bg-black/60 backdrop-blur-md'>
                <div className=' max w-full flex flex-wrap justify-between max-md:justify-center font-bricolage text-center  capitalize p-4 gap-2'>

                    {
                        chiffres.map((element) => (
                            <motion.div
                                variants={Animations.scale({ duration: 0.3 * chiffres.indexOf(element) })}
                                initial="hidden"
                                whileInView="show"
                                key={element.titre} className='font-jost 
                                flex flex-col items-center
                                w-72  p-2
                                border-t-8 border-orange-500 border rounded-b-xl '>
                                <h1 className='text-4xl md:text-6xl'> {element.titre} <span className='text-2xl'>{element.subtitre}</span></h1>
                                <p className='text-base md:text-lg font-semibold text-orange-50'>{element.description}</p>
                            </motion.div>
                        ))
                    }


                </div>
            </div>
        </div>
    )
}

export default Satisfaction