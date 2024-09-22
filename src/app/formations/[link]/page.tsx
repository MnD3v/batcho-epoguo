"use client"
import AppBar from '@/app/components/app_bar';
import Animations from '@/app/components/utils/item';
import { formations } from '@/app/constants';
import { motion } from 'framer-motion';
import Image from 'next/image';
import { useEffect, useState } from 'react';
const Formation = ({ params }: { params: { link: string } }) => {





    const formation = formations.find((e) => {
        console.log(params);
        console.log(e.link);

        return e.link === params.link
    })!;


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
                variants={Animations.opacity({ duration: 0.4 })}
                initial="hidden"
                whileInView="show"
                className=''>
                <div
                    style={{
                        backgroundImage: "radial-gradient(#fb923c 1px, transparent 0)",
                        backgroundSize: "20px 20px"
                    }}
                    className='bg-orange-100 flex flex-col items-center font-jost'>
                    <AppBar></AppBar>

                    <div className=' justify-center items-center mb-8 md:my-12 mx-2 space-y-3'>
                        <h1 className='text-center text-2xl md:text-4xl'>FORMATIONS </h1>

                        <h2 className='text-center text-xl md:text-3xl text-orange-600'>{formation?.title}</h2>
                    </div>

                </div>
                <div className='w-full flex justify-center'>
                    <div className='max-w-[800px] leading-relaxed'>

                        <div className='m-2 md:m-9'>
                            <Image
                                src={formation.image}
                                width={500}
                                height={500}
                                alt="" className='h-[200px] sm:h-[300px] md:h-[500px] w-full object-cover' />
                            <h1 className='font-bricolage text-2xl md:text-4xl text-orange-600 mt-6'>{formation?.title}</h1>
                            <div className='h-px w-28 bg-blue-900 my-3'></div>
                            <p>{formation?.full_description}</p>
                            <h2 className='text-orange-600 font-bricolage mt-6'>Débouchés</h2>
                            {
                                formation?.debouches?.split("*").map((element) => (
                                    <div key={element}><p> <span className='font-bricolage font-bold text-lg'>-{element.split(':')[0]} </span>:{element.split(':')[1]}</p></div>
                                ))
                            }
                            <h2 className='font-bricolage text-orange-600 mt-6'>Unités d'enseignement</h2>
                            {
                                formation?.ues?.split("*").map((element) => (
                                    <div key={element}><p className='font-semibold'>- {element}</p></div>
                                ))
                            }
                        </div>
                    </div>
                </div>
            </motion.div>
        </div>

    )
}

export default Formation