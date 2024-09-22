import { motion } from 'framer-motion'
import React from 'react'
import Animations from './utils/item'

const Contact = () => {

    const contacts = [{ icon: "messages.png", title: "Ecrivez nous un message", description: "Nous avons des experts en social en direct qui attendent pour vous aider du lundi au vendredi de 7h à 18h", buttonText: "Envoyer un message", link: "" }, { icon: "mail.png", title: "Envoyez nous un mail", description: "Nous avons des experts en social en direct qui attendent pour vous aider du lundi au vendredi de 7h à 18h", buttonText: "Envoyer un mail", link: "" }, { icon: "call.png", title: "Appelez nous", description: "Nous avons des experts en social en direct qui attendent pour vous aider du lundi au vendredi de 7h à 18h", buttonText: "+228 90559055", link: "" },]
    return (
        <section id="contact">
            <div className='flex justify-center'>
                <div className='max md:flex md:justify-between w-full  bg-orange-100 p-6 md:p-16 my-12'>
                    <div className='font-bricolage w-[43%] max-md:w-full'>
                        <motion.h1
                            variants={Animations.leftToRight({ duration: 0.6 })}
                            initial="hidden"
                            whileInView="show"
                            className='text-3xl md:text-5xl font-normal'>
                            Choisissez <span className='text-orange-500 font-bold'>Groupe batcho</span>  pour une satisfaction complète.
                        </motion.h1>
                        <motion.p
                            variants={Animations.bottomToTop({ duration: 0.3, begin: 50 })}
                            initial="hidden"
                            whileInView="show"
                        >

                            Devenez le professionnel du digital que vous avez toujours rêvé d'être. Nos formations vous équipent des compétences clés pour réussir dans le monde digital en constante évolution. Bénéficiez d'un accompagnement personnalisé et donnez un coup de boost à votre carrière.</motion.p>
                    </div>
                    <div className='w-full md:max-w-[43%]'>
                        <div className='w-full flex flex-col md:grid md:grid-cols-2 gap-3'>
                            <input type="text" name="" placeholder='Nom complet' id="" className='px-1 w-full py-3 border-b-[1px] border-zinc-500 bg-transparent ' />
                            <input type="number" name="" placeholder='Téléphone' id="" className='px-1 w-full py-3 border-b-[1px] border-zinc-500 bg-transparent' />
                            <textarea name="" placeholder='Votre message' id="" className='md:col-span-2 px-1 w-full py-3 border-b-[1px] border-zinc-500 bg-transparent' />
                        </div>
                        <motion.button
                            variants={Animations.scale({ duration: 0.3 })}
                            initial="hidden"
                            whileInView="show"
                            className='bg-orange-600 text-white font-semibold px-8 py-4 my-4'>Envoyer</motion.button>
                    </div>
                </div>

            </div>
            <div className='flex flex-wrap justify-center gap-3 m-3'>
                {contacts.map((element) => (
                    <motion.div

                        variants={Animations.bottomToTop({ duration: 0.4 * contacts.indexOf(element) + 0.4, })}
                        initial="hidden"
                        whileInView="show"
                        viewport={{ once: true }}
                        key={element.icon} className='w-full sm:w-96 bg-orange-100 rounded-xl flex flex-col items-center p-4 gap-3'>
                        <div className='h-20 w-20 md:h-24 md:w-24 rounded-full bg-orange-100 flex flex-col items-center justify-center'>
                            <img src={`/icons/${element.icon}`} alt="" className='h-10 md:h-14 ' />
                        </div>
                        <h3 className='text-orange-900'>{element.title}</h3>
                        <p className='text-center'>{element.description} </p>
                        <a href="" className='text-orange-900 font-bricolage px-6 py-4 bg-orange-100 border border-orange-600 rounded-lg'>{element.buttonText}</a>
                    </motion.div>
                ))}
            </div>
        </section>

    )
}

export default Contact