import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing for the store. The upload key and its passwords live
// outside the repository: android/key.properties (git-ignored) names them:
//   storeFile=<path to the .jks>   storePassword=…   keyAlias=…   keyPassword=…
// Without it a release build stops; it is never signed with the debug key.
// Debug (and profile) builds use the debug key.
val uploadKeyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasUploadKey = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !uploadKeyProperties.getProperty(it).isNullOrBlank() }

// AdMob App ID (AndroidManifest.xml, com.google.android.gms.ads.APPLICATION_ID).
// Debug and profile always use Google's sample App ID, so they never request
// real ads. A release takes the real IDs from the dart-defines that
// `--dart-define-from-file=config/ads.local.json` (git-ignored) hands Gradle
// as `-Pdart-defines` (comma-separated base64 "KEY=VALUE" entries), and stops
// when one is missing, malformed or Google's sample ID (check below).
// The IDs are never printed.
val admobSamplePublisher = "ca-app-pub-3940256099942544"
val admobTestAppId = "$admobSamplePublisher~3347511713"
val dartDefines: Map<String, String> = (project.findProperty("dart-defines") as String?)
    .orEmpty()
    .split(",")
    .filter { it.isNotBlank() }
    .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    .filter { it.indexOf('=') > 0 }
    .associate { it.substringBefore('=') to it.substringAfter('=').trim() }
val admobReleaseProblems: List<String> = listOf(
    "ADMOB_ANDROID_APP_ID" to Regex("""ca-app-pub-\d+~\d+"""),
    "ADMOB_ANDROID_BANNER_ID" to Regex("""ca-app-pub-\d+/\d+"""),
    "ADMOB_ANDROID_REWARDED_ID" to Regex("""ca-app-pub-\d+/\d+"""),
).mapNotNull { (key, pattern) ->
    val value = dartDefines[key].orEmpty()
    when {
        value.isEmpty() -> "$key is missing"
        value.startsWith(admobSamplePublisher) -> "$key is Google's test ID"
        !pattern.matches(value) -> "$key is not an AdMob ID"
        else -> null
    }
}

android {
    namespace = "com.worldmystery.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.worldmystery.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "World Mystery"
        // Debug and profile: Google's sample App ID (release overrides it).
        manifestPlaceholders["admobAppId"] = admobTestAppId
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(uploadKeyProperties.getProperty("storeFile"))
                storePassword = uploadKeyProperties.getProperty("storePassword")
                keyAlias = uploadKeyProperties.getProperty("keyAlias")
                keyPassword = uploadKeyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // The upload key only: no debug-key fallback (see the check below).
            signingConfig = if (hasUploadKey) signingConfigs.getByName("upload") else null
            // The real App ID only (a release without it stops below).
            manifestPlaceholders["admobAppId"] =
                if (admobReleaseProblems.isEmpty()) dartDefines.getValue("ADMOB_ANDROID_APP_ID") else ""
        }
    }
}

// A release without the real AdMob IDs, or without the upload key, stops here
// instead of producing a build with sample ads, or an unsigned or
// debug-signed one.
gradle.taskGraph.whenReady {
    val release = allTasks.any { it.project == project && it.name.contains("Release") }
    if (release && admobReleaseProblems.isNotEmpty()) {
        throw GradleException(
            "A release build needs the real AdMob IDs: ${admobReleaseProblems.joinToString("; ")}. " +
                "Build with --dart-define-from-file=config/ads.local.json (see config/ads.example.json).",
        )
    }
    if (release && !hasUploadKey) {
        throw GradleException(
            "A release build needs the upload key: create android/key.properties (see app/build.gradle.kts). " +
                "It is never signed with the debug key.",
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
