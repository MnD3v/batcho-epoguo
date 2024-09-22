import { motion } from 'framer-motion'
import React from 'react'
import Animations from './utils/item'

const APropos = () => {
    const avantages = [

        { icon: "enseignants.png", description: "Formateurs experts: Nos formateurs sont des professionnels du secteur, prêts à partager leur expérience et savoir-faire." },
        { icon: "mind.png", description: "Méthodes d'apprentissage innovantes: Utilisation des dernières technologies et outils pour un apprentissage pratique et efficace.", }, { icon: "business.png", description: "Partenariats avec des entreprises: Nous collaborons avec des entreprises locales et internationales pour faciliter l'insertion professionnelle de nos apprenants.", }, { icon: "certificate.png", description: "Certifications reconnues: Nos formations sont certifiées et reconnues dans le secteur numérique." },

    ]
    return (
        <section id="a-propos" className='flex  justify-center p-3'>
            <div className='max flex flex-wrap gap-3'>
                <motion.img src="/entreprise.jpg" alt=""

                    variants={Animations.leftToRight({ duration: 0.5 })}
                    initial="hidden"
                    whileInView="show"
                    className='object-cover w-full h-[260px] sm:h-[400px] lg:w-[50%] lg:h-auto' />
                <div className='w-full lg:w-[400px] xl:w-[600px]'>
                    <div className='flex items-center'>
                        <div className='h-2 w-2 bg-orange-600 m-2'></div>

                        <p className='text-orange-600 uppercase font-poppins font-bold'>A propos de nous</p>
                        <div className='h-2 w-2 bg-orange-600 m-2'></div>

                    </div>
                    <h1 className='font-jost text-2xl md:text-3xl text-orange-900 leading-tight
                    my-3
                    '>
                        Nous sommes un agence offrant des formations aux jeunes sur le territoire .Togolais  Des clients nous font confiance depuis 2014
                    </h1>
                    <h3 className='text-orange-600 text-2xl font-bricolage'>
                        Atouts</h3>
                    <div className='flex flex-wrap'>

                        {
                            avantages.map((element) => (
                                <motion.div
                                    variants={Animations.bottomToTop({ duration: 0.3 * avantages.indexOf(element) })}
                                    initial="hidden"
                                    whileInView="show"
                                    key={element.icon}
                                    className='flex items-start 
                                my-4 gap-3
                                w-full sm:w-72
                                '>

                                    <div className='h-16 w-16 rounded-md bg-orange-200 flex items-center justify-center'>
                                        <img src={"/icons/" + element.icon} alt="" className='h-9' />
                                    </div>
                                    <div className='w-full sm:w-52'>
                                        <p className='text-orange-700 font-jost text-xl font-semibold'>{element.description.split(':')[0]} </p>
                                        <p>{element.description.split(':')[1]}</p>
                                    </div >

                                </motion.div>
                            ))
                        }

                    </div>

                </div>
            </div>
        </section>
    )
}

export default APropos