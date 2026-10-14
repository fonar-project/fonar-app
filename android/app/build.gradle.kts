import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.fonar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.fonar"
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
    }

    // A chave de release (US41). Fica FORA do repositório — é ela que prova
    // que uma atualização do APK vem de quem fez o primeiro. Vem de um de
    // dois lugares, nesta ordem:
    //
    // - `android/key.properties` (ignorado pelo git), na máquina de quem
    //   publica: storeFile, storePassword, keyAlias, keyPassword;
    // - as variáveis FONAR_KEYSTORE, FONAR_KEYSTORE_SENHA, FONAR_CHAVE_ALIAS
    //   e FONAR_CHAVE_SENHA, no workflow de release (secrets do GitHub).
    //
    // Sem nenhum dos dois, o release sai com a chave de debug: serve para
    // testar, e o workflow de release avisa que não é para distribuir. Ver
    // "Distribuição" no README.
    val chave = Properties().apply {
        val arquivo = rootProject.file("key.properties")
        if (arquivo.exists()) arquivo.inputStream().use { load(it) }
    }
    fun daChave(propriedade: String, variavel: String): String? =
        chave.getProperty(propriedade) ?: System.getenv(variavel)
    val arquivoDaChave = daChave("storeFile", "FONAR_KEYSTORE")

    signingConfigs {
        if (arquivoDaChave != null) {
            create("release") {
                storeFile = file(arquivoDaChave)
                storePassword = daChave("storePassword", "FONAR_KEYSTORE_SENHA")
                keyAlias = daChave("keyAlias", "FONAR_CHAVE_ALIAS")
                keyPassword = daChave("keyPassword", "FONAR_CHAVE_SENHA")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (arquivoDaChave != null) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
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
