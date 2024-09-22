'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';

const BottomNotification = () => {
    const [showNotification, setShowNotification] = useState(false);

    const handleSendMessage = () => {
        console.log("Message envoyé");

        setShowNotification(true);

        setTimeout(() => {
            setShowNotification(false);
        }, 3000);
    };

    return (
        <div className="relative">
            <button
                onClick={handleSendMessage}
                className="bg-blue-500 text-white py-2 px-4 rounded mt-4"
            >
                Envoyer le message
            </button>

            {showNotification && (
                <motion.div
                    initial={{ opacity: 0, y: 50 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: 50 }}
                    className="fixed bottom-4 left-1/2 transform -translate-x-1/2 bg-green-500 text-white px-4 py-2 rounded shadow-lg"
                >
                    Message envoyé avec succès !
                </motion.div>
            )}
        </div>
    );
};

export default BottomNotification;
