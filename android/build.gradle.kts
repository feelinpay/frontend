allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // NUCLEAR: Forzar silencio absoluto en todos los subproyectos
    gradle.projectsEvaluated {
        tasks.withType<JavaCompile>().configureEach {
            options.isDeprecation = false
            options.isWarnings = false
            // options.compilerArgs.clear() // REMOVED: Unsafe
            options.compilerArgs.addAll(listOf("-Xlint:none", "-nowarn"))
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

rootProject.buildDir = File("../build")
subprojects {
    project.buildDir = File("${rootProject.buildDir}/${project.name}")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
