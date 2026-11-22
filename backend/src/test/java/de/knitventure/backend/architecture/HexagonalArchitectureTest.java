package de.knitventure.backend.architecture;

import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.jmolecules.architecture.hexagonal.Application;
import org.jmolecules.architecture.hexagonal.PrimaryAdapter;
import org.jmolecules.architecture.hexagonal.PrimaryPort;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

class HexagonalArchitectureTest {

    @Test
    void identifiesEachHexagonalRoleAndKeepsAdaptersOutOfTheApplicationCore() {
        var backendClasses = new ClassFileImporter()
                .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
                .importPackages("de.knitventure.backend");

        classes().that().resideInAPackage("..application")
                .should().beAnnotatedWith(Application.class)
                .check(backendClasses);
        classes().that().resideInAPackage("..application.port..")
                .should().beAnnotatedWith(PrimaryPort.class)
                .check(backendClasses);
        classes().that().resideInAPackage("..adapter.http..")
                .and().areTopLevelClasses()
                .should().beAnnotatedWith(PrimaryAdapter.class)
                .check(backendClasses);
        noClasses().that().resideInAPackage("..application..")
                .should().dependOnClassesThat().resideInAPackage("..adapter..")
                .check(backendClasses);
    }
}
