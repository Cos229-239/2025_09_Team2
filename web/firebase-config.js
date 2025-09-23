// Firebase configuration for StudyPals web app
const firebaseConfig = {
  apiKey: "AIzaSyCEtnDvfNnzgtMSZmNy00NTRhLWlxNTAtZm",
  authDomain: "studypals-9f7e1.firebaseapp.com",
  projectId: "studypals-9f7e1",
  storageBucket: "studypals-9f7e1.firebaseapp.com",
  messagingSenderId: "251508884392",
  appId: "1:251508884392:web:7a842b1e9867506d09539d",
  measurementId: "G-1J3NYP637K"
};

// Initialize Firebase
import { initializeApp } from 'firebase/app';
import { getAnalytics } from 'firebase/analytics';

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export { app, analytics };