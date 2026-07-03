importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Initialize Firebase in the service worker.
// These credentials match the DefaultFirebaseOptions.web config from firebase_options.dart.
firebase.initializeApp({
  apiKey: "AIzaSyDSS00Yery8LOI5IpMcp5KX9xi3zSxewpY",
  appId: "1:357712980558:web:a9db241e2fd1b0b41af11f",
  messagingSenderId: "357712980558",
  projectId: "emran-wallet-share",
  authDomain: "emran-wallet-share.firebaseapp.com",
  storageBucket: "emran-wallet-share.firebasestorage.app",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title || 'WalletShare';
  const notificationOptions = {
    body: payload.notification.body || '',
    icon: '/favicon.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
