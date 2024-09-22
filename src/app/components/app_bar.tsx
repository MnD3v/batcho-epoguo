"use client"
import { motion } from 'framer-motion'
import React, { useEffect, useRef, useState } from 'react'
import { useGlobalState } from '../contexts/GlobalStateContext';
import { usePathname } from 'next/navigation';

const AppBar = () => {
    const { menuIsOpen, setMenuIsOpen } = useGlobalState();

    const menuRef = useRef<HTMLDivElement>(null)

    const pathName = usePathname()
    const [inNotHome, setInNotHome] = useState(false)



    useEffect(() => {
        if (!(pathName === '/')) {
            setInNotHome(true)
        }
        const handleScroll = () => {

            setMenuIsOpen(false)
        }



        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
                setMenuIsOpen(false)
            }
        }

        window.addEventListener('scroll', handleScroll)
        document.addEventListener('mousedown', handleClickOutside);
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
            window.removeEventListener('scroll', handleScroll)
        }


    }, [])



    return (
        <div className='w-full'>


            <div className={` fixed ${menuIsOpen ? "block" : "hidden"} h-full w-full bg-black/30`}>

            </div>
            <MobileAppBar inNotHome={inNotHome} menuIsOpen={menuIsOpen} menuRef={menuRef}></MobileAppBar>
            <div className='w-full flex justify-center'>
                <div className='max w-full flex flex-col items-center '>
                    {/* infos contact */}

                    <div className="max w-full  justify-end hidden md:flex
                    px-12
                    ">
                        <div className="flex font-bricolage gap-6 items-center">
                            <div className='flex items-center'>
                                <img src="/icons/clock.png" alt="" className='h-6 m-1' />
                                <div>
                                    <p className="font-semibold">Lundi - Vendredi 08:00 - 19:00</p>
                                    <p>Samedis et Dimanches - FERMÉ</p>
                                </div>
                            </div>

                            <div className='flex items-center'>
                                <img src="/icons/phone.png" alt="" className='h-6 m-1' />

                                <div>
                                    <p className="font-semibold">+228 90 90 90 90</p>
                                    <p>batchoepoguo@gmail.com</p>
                                </div>
                            </div>

                        </div>

                    </div>
                    {/* infos contact */}
                    <div className='p-6 hidden justify-between w-full md:flex'>
                        <a href={inNotHome ? "/" : "#"}> <img src="/black-logo.png" alt="" className="h-12 md:h-20" />
                        </a>

                        <ul className="max flex font-jost">
                            <li className="hover:text-orange-600 font-semibold  border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#"}>Accueil</a></li>
                            <li className="hover:text-orange-600 font-semibold  border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#formations"}>Formations</a></li>

                            <li className="hover:text-orange-600 font-semibold  border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#a-propos"}>A Propos</a></li>
                            <li className="hover:text-orange-600 font-semibold  border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#contact"}>Contact</a></li>
                        </ul>
                    </div>
                    <div className='w-full flex md:hidden  justify-between  items-center
                    p-6
                    '>
                        <img src="/black-logo.png" alt="" className="h-10 md:h-16" />
                        <button
                            onClick={() => {

                                setMenuIsOpen((!menuIsOpen))
                                console.log(menuIsOpen)
                            }} >
                            <img src={menuIsOpen ? "/icons/close.png" : "/icons/black-menu.png"} alt="" className='h-5 ' />
                        </button>
                    </div>
                </div>
            </div>

        </div>
    )
}

export default AppBar


const MobileAppBar = ({ menuRef, menuIsOpen, inNotHome }: { menuRef: React.RefObject<HTMLDivElement>, menuIsOpen: boolean, inNotHome: boolean }) => (
    <motion.div ref={menuRef}
        initial={{ x: "-300px" }}
        animate={{ x: menuIsOpen ? "0" : "-300px", transition: { duration: 0.25 } }}
        className='fixed flex flex-col justify-between bg-white w-[300px] h-full p-6 text-black z-50'>

        <ul className={` my-9 flex flex-col items-center justify-center `}>
            <li className="hover:text-orange-600 font-semibold  border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#"}>Accueil</a></li>
            <li className="hover:text-orange-600 font-semibold  border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#formations"}>Formations</a></li>

            <li className="hover:text-orange-600 font-semibold  border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#a-propos"}>A Propos</a></li>
            <li className="hover:text-orange-600 font-semibold  border-white/30 px-6 py-3"><a href={inNotHome ? "/" : "#contact"}>Contact</a></li>
        </ul>
        <div className="flex flex-wrap gap-4">

            <img src="/black-logo.png" alt="" className="h-14" />

            <div className=" font-bricolage gap-6 items-center space-y-3">
                <div className='flex'>
                    <img src="/icons/clock.png" alt="" className='h-4 m-1' />
                    <div>
                        <p className="font-semibold">Lundi - Vendredi 08:00 - 19:00</p>
                        <p>Samedis et Dimanches - FERMÉ</p>
                    </div>
                </div>

                <div className='flex'>
                    <img src="/icons/phone.png" alt="" className='h-4 m-1' />

                    <div>
                        <p className="font-semibold">+228 90 90 90 90</p>
                        <p>batcho@group.com</p>
                    </div>
                </div>

            </div>

        </div>

    </motion.div>
)