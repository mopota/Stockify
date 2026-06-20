import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAkgy8hXGyb_c1pa3wwHRQ9nDgnM4UppIM',
    appId: '1:126042053790:web:185473ec4e49efcf446f8f',
    messagingSenderId: '126042053790',
    projectId: 'project-1-94f6f',
    authDomain: 'project-1-94f6f.firebaseapp.com',
    storageBucket: 'project-1-94f6f.appspot.com',
    measurementId: 'G-K313S0Z6R0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYyaWttQPKetUTqdcXJO3S4mMS-eg-Goo',
    appId: '1:126042053790:android:8b39ae4fa33cf4d3446f8f',
    messagingSenderId: '126042053790',
    projectId: 'project-1-94f6f',
    storageBucket: 'project-1-94f6f.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBsuvOKv4afH1jKlX3MeC7zGw6SC3BzwGY',
    appId: '1:126042053790:ios:b5edbd14c65efa36446f8f',
    messagingSenderId: '126042053790',
    projectId: 'project-1-94f6f',
    storageBucket: 'project-1-94f6f.appspot.com',
    iosClientId: '126042053790-mq848kn96ctf2la9s9dajjh0miadkbm2.apps.googleusercontent.com',
    iosBundleId: 'com.project1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBsuvOKv4afH1jKlX3MeC7zGw6SC3BzwGY',
    appId: '1:126042053790:ios:b5edbd14c65efa36446f8f',
    messagingSenderId: '126042053790',
    projectId: 'project-1-94f6f',
    storageBucket: 'project-1-94f6f.appspot.com',
    iosClientId: '126042053790-mq848kn96ctf2la9s9dajjh0miadkbm2.apps.googleusercontent.com',
    iosBundleId: 'com.project1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAkgy8hXGyb_c1pa3wwHRQ9nDgnM4UppIM',
    appId: '1:126042053790:web:1ffbeaf1c3649aa7446f8f',
    messagingSenderId: '126042053790',
    projectId: 'project-1-94f6f',
    authDomain: 'project-1-94f6f.firebaseapp.com',
    storageBucket: 'project-1-94f6f.appspot.com',
    measurementId: 'G-JE73PT75XK',
  );
}
