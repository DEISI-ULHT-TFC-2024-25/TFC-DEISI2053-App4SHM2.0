## Deploy a new version

* Change the version on pubspec.yaml. Example: 0.9.0+1 (versionName is 0.9.0 and versionCode is 1)
* cd android; fastlane alpha
* cd ios; fastlane beta

(not obsolete anymore)
* flutter build appbundle (android)
* flutter build ipa (ios)
  * (for distribution) flutter build ipa --export-options-plist=ios/ExportOptions.plist
  * it may be necessary to import the certificate (ios/ios_distribution.cer) into the keychain (use System)

## (obsolete) How to fastlaneize an existing flutter project

* Install fastlane (brew)
* Make sure flutter build appbundle and flutter build ipa work
* Android
  * Go to the Android folder and run fastlane init
  * Check that package_name in [project]/android/fastlane/Appfile matches your package name in AndroidManifest.xml.
  * Manually create the first release for closed testing on google play console (https://play.google.com/console/)
  * Go to Setup -> API access (instruction borrowed from https://docs.fastlane.tools/getting-started/android/setup/#setting-up-supply but they are outdated)
    * On the page, search for the Credentials section and Service Accounts
    * Click on the "Learn how to create service accounts" and follow the steps. Within the creation, make sure to Create New Key in JSON format.
    * Store the JSON Key in android/fastlane but don't commit this file (add it to .gitignore)
    * Don't forget to grant access for the new service, with Admin (all permissions) and Invite User to finish
    * Make sure your Appfile is like this:
    
    json_key_file("fastlane/pc-api-8480337879654529589-116-9094764400c9.json")
    package_name("pt.ulusofona.deisi.labs.app4shm2")
    
  * Change Fastfile for this:

    default_platform(:android)
    
    platform :android do
    desc "Upload a alpha build to Google Play"
    lane :alpha do
    gradle(task: "clean")
    
          # Build the Flutter app for release with the desired flavor (e.g., "dev" or "prod")
          sh "flutter build appbundle"
    
          # Upload the AAB to Google Play
          supply(
            package_name: "pt.ulusofona.deisi.labs.app4shm2", # Replace with your app's package name
            aab: "../build/app/outputs/bundle/release/app-release.aab", # Replace with the path to your APK file
            track: "alpha", # Change this to "alpha" if you want to upload to the alpha track instead
            release_status: 'draft',
            skip_upload_metadata: true # Set this to false if you want to fill in the release metadata interactively
          )
        end
    end
  * run fastlane supply init to download metadata (you may need to delete the metadata folder)
  
* iOS
  * Go to the iOS folder and run fastlane init
  * You need to create an app password. Go to https://appleid.apple.com/, and choose App-specific passwords. Create one.
  * Add a .env file inside ios/fastlane like this (make sure this file is not commited, add to .gitignore):

    FASTLANE_USER=???@???? # appleid
    FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=????-????-????-????
  
  * Change Fastfile for this:

    default_platform(:ios)
    
    platform :ios do
    desc "Push a new beta build to TestFlight"
    lane :beta do
    sh "flutter build ipa"
    
        upload_to_testflight(
            skip_submission: true,
            ipa: "../build/ios/ipa/app4shm.ipa",
            skip_waiting_for_build_processing: true,
          )
    end
  
  * Didn't experiment with api keys, here's an article explaining that: https://www.hapq.me/two-ways-to-upload-ipa-to-testflight-with-fastlane/ 
    

## TODO

Integrate into github actions. see example: https://github.com/flutter/gallery/blob/main/.github/workflows/release_deploy_play_store.yml