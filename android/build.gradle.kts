// Root build.gradle.kts — Cleaned up for Flutter new plugin-based project structure
//
// All plugin versions (AGP, Kotlin, Flutter) are declared in settings.gradle.kts
// using the pluginManagement{} and plugins{} blocks. The old buildscript{} block
// is NOT needed here and caused "Unresolved reference: ext/kotlin_version" errors.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}