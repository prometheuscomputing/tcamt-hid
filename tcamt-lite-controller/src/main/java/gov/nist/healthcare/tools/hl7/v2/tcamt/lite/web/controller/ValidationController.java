package gov.nist.healthcare.tools.hl7.v2.tcamt.lite.web.controller;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import gov.nist.healthcare.nht.acmgt.repo.AccountRepository;
import gov.nist.healthcare.nht.acmgt.service.UserService;
import gov.nist.healthcare.tools.hl7.v2.tcamt.lite.domain.TestStep;
import gov.nist.healthcare.tools.hl7.v2.tcamt.lite.domain.ValidationContainer;
import gov.nist.healthcare.tools.hl7.v2.tcamt.lite.domain.profile.ProfileData;
import gov.nist.healthcare.tools.hl7.v2.tcamt.lite.domain.view.TestStepSupplementsParams;
import gov.nist.healthcare.tools.hl7.v2.tcamt.lite.service.ProfileService;
import gov.nist.healthcare.tools.hl7.v2.tcamt.lite.web.util.GenerationUtil;
import gov.nist.healthcare.unified.model.EnhancedReport;
import gov.nist.healthcare.unified.model.Section;
import gov.nist.validation.report.Report;
import hl7.v2.validation.SyncHL7Validator;
import hl7.v2.validation.ValidationContext;
import hl7.v2.validation.ValidationContextBuilder;
import scala.collection.JavaConverters;

@RestController
public class ValidationController {

  Logger log = LoggerFactory.getLogger(TestPlanController.class);

  @Autowired
  UserService userService;

  @Autowired
  ProfileService profileService;

  @Autowired
  AccountRepository accountRepository;

  @RequestMapping(value = "/validation", method = RequestMethod.POST)
  public String Validate(@RequestParam(value = "igDocumentId") String igDocumentId,
      @RequestParam(value = "conformanceProfileId") String conformanceProfileId,
      @RequestParam(value = "context") String contextMode,
      @RequestBody ValidationContainer validationContainer) throws Exception {

    String html = "";
    String error = "";
    String response = "";

    ProfileData pData = profileService.findOne(igDocumentId);
    if (pData == null) {
      JSONObject missing = new JSONObject();
      missing.put("json", "");
      missing.put("html", "");
      missing.put("error", "Profile not found");
      return missing.toString();
    }

    String message = validationContainer.getMessage();
    boolean contextBased = "based".equalsIgnoreCase(contextMode);
    List<InputStream> confContexts = new ArrayList<InputStream>();

    if (hasText(pData.getConstraintsXMLFileStr())) {
      confContexts.add(toStream(pData.getConstraintsXMLFileStr()));
    }

    if (contextBased) {
      String stepConstraints = buildStepConstraints(validationContainer.getTs());
      if (hasText(stepConstraints)) {
        confContexts.add(0, toStream(stepConstraints));
      }
    }

    try {
      if (!hasText(pData.getProfileXMLFileStr())) {
        throw new IllegalArgumentException("Profile XML is missing");
      }
      if (!hasText(message)) {
        throw new IllegalArgumentException("Message is missing");
      }

      ValidationContextBuilder builder =
          new ValidationContextBuilder(toStream(pData.getProfileXMLFileStr()));
      if (hasText(pData.getValueSetXMLFileStr())) {
        builder.useValueSetLibrary(toStream(legacyValueSetXml(pData.getValueSetXMLFileStr())));
      }
      if (!confContexts.isEmpty()) {
        builder.useConformanceContext(
            JavaConverters.asScalaBufferConverter(confContexts).asScala().toList());
      }
      applyOptional(builder, pData.getBindingXMLFileStr(), "value set bindings",
          new ArtifactApplier() {
            public void apply(ValidationContextBuilder target, String xml) {
              target.useVsBindings(toStream(xml));
            }
          });
      applyOptional(builder, pData.getCoconstraintsXMLFileStr(), "co-constraints",
          new ArtifactApplier() {
            public void apply(ValidationContextBuilder target, String xml) {
              target.useCoConstraintsContext(toStream(xml));
            }
          });
      applyOptional(builder, pData.getSlicingXMLFileStr(), "slicings",
          new ArtifactApplier() {
            public void apply(ValidationContextBuilder target, String xml) {
              target.useSlicingContext(toStream(xml));
            }
          });

      ValidationContext validationContext = builder.getValidationContext();
      Report report = new SyncHL7Validator(validationContext).check(message, conformanceProfileId);

      Section service = new Section("service");
      service.put("name", "Unified Report Test Application");
      service.put("provider", "NIST");
      ArrayList<Section> metadata = new ArrayList<Section>();
      metadata.add(service);

      EnhancedReport enhanced = EnhancedReport.fromValidation(report, message,
          pData.getProfileXMLFileStr(), conformanceProfileId, metadata,
          contextBased ? "Context-Based" : "Context-Free");
      response = enhanced.to("json").toString();
      html = enhanced.render("report", null);
    } catch (Throwable e) {
      error = e.getMessage();
      log.error("HL7 v2 validation failed", e);
    }

    JSONObject obj = new JSONObject();
    obj.put("json", response);
    obj.put("html", html);
    obj.put("error", error);
    return obj.toString();
  }

  private String buildStepConstraints(TestStep testStep) {
    if (testStep == null) {
      return null;
    }
    try {
      TestStepSupplementsParams params = new TestStepSupplementsParams();
      params.setConformanceProfileId(testStep.getConformanceProfileId());
      params.setEr7Message(testStep.getEr7Message());
      params.setIntegrationProfileId(testStep.getIntegrationProfileId());
      params.setTestDataCategorizationMap(testStep.getTestDataCategorizationMap());
      params.setOrderIndifferentInfoMap(testStep.getOrderIndifferentInfoMap());
      params.setFieldOrderIndifferentInfoMap(testStep.getFieldOrderIndifferentInfoMap());
      ProfileData constraintProfile = profileService.findOne(params.getIntegrationProfileId());
      if (constraintProfile == null) {
        return null;
      }
      ConstraintXMLOutPut generated =
          new GenerationUtil().getConstraintsXML(null, params, constraintProfile);
      if (generated == null) {
        return null;
      }
      return generated.getXmlStr();
    } catch (Exception e) {
      log.warn("Context-based step constraints were not generated: {}", e.getMessage());
      return null;
    }
  }

  private void applyOptional(ValidationContextBuilder builder, String xml, String label,
      ArtifactApplier applier) {
    if (!hasText(xml)) {
      return;
    }
    try {
      applier.apply(builder, xml);
    } catch (Throwable e) {
      log.warn("Skipping {} for validation: {}", label, e.getMessage());
    }
  }

  private static String legacyValueSetXml(String xml) {
    return xml.replaceAll("\\s+CodePattern=\"[^\"]*\"", "").replaceAll("\\s+CodePattern='[^']*'",
        "");
  }

  private static boolean hasText(String value) {
    return value != null && !value.trim().isEmpty();
  }

  private static InputStream toStream(String xml) {
    return new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8));
  }

  private interface ArtifactApplier {
    void apply(ValidationContextBuilder builder, String xml);
  }
}
