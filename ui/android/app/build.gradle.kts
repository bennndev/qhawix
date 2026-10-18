import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyPropertiesFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties()
if (releaseKeyPropertiesFile.exists()) {
    releaseKeyPropertiesFile.inputStream().use(releaseKeyProperties::load)
}

android {
    namespace = "pe.qhawix.qhawix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "pe.qhawix.qhawix"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKeyPropertiesFile.exists()) {
            create("qhawixRelease") {
                val storePath = releaseKeyProperties.getProperty("storeFile")
                storeFile = storePath?.let { rootProject.file(it) }
                storePassword = releaseKeyProperties.getProperty("storePassword")
                keyAlias = releaseKeyProperties.getProperty("keyAlias")
                keyPassword = releaseKeyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseKeyPropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("qhawixRelease")
            } else {
                signingConfig = null
            }
        }
    }
}

tasks.configureEach {
    val releaseArtifactTask = name.endsWith("Release") &&
        (name.startsWith("assemble") || name.startsWith("package") || name.startsWith("bundle"))
    if (releaseArtifactTask) {
        doFirst {
            if (!releaseKeyPropertiesFile.exists()) {
                throw GradleException(
                    "Release APK signing is not configured. Create ui/android/key.properties " +
                        "and provide the protected release keystore outside the repository.",
                )
            }
            val requiredProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
            val missing = requiredProperties.filter { releaseKeyProperties.getProperty(it).isNullOrBlank() }
            if (missing.isNotEmpty()) {
                throw GradleException("Release signing configuration is missing: ${missing.joinToString()}")
            }
        }
    }
}

flutter {
    source = "../.."
}
