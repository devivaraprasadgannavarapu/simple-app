package com.example.sampleapp;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.http.MediaType;

@SpringBootApplication
public class SampleAppApplication {
    public static void main(String[] args) {
        SpringApplication.run(SampleAppApplication.class, args);
    }
}

@RestController
class RuntimeController {
    private final int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));

    @GetMapping(value = "/health", produces = MediaType.APPLICATION_JSON_VALUE)
    Map<String, String> health() {
        return Map.of("status", "ok", "pod", value("POD_NAME"));
    }

    @RequestMapping(value = "/", produces = MediaType.TEXT_HTML_VALUE)
    String page() {
        Map<String, String> runtime = new LinkedHashMap<>();
        runtime.put("Pod name", value("POD_NAME"));
        runtime.put("Namespace", value("POD_NAMESPACE"));
        runtime.put("Node name", value("NODE_NAME"));
        runtime.put("Pod IP", value("POD_IP"));
        runtime.put("Node IP", value("NODE_IP"));
        runtime.put("Container port", String.valueOf(port));

        Map<String, String> infrastructure = new LinkedHashMap<>();
        infrastructure.put("Cluster control", "1 control plane");
        infrastructure.put("Compute", "2 worker nodes");
        infrastructure.put("Application scale", "2 application pods");
        infrastructure.put("Service", "sample-app Service");
        infrastructure.put("Public entry", "NodePort 32621 -> port 80 -> container port 8080");
        infrastructure.put("Pod networking", "Calico pod network");

        return html(runtime, infrastructure);
    }

    private String value(String name) {
        return System.getenv().getOrDefault(name, "unknown");
    }

    private String html(Map<String, String> runtime, Map<String, String> infrastructure) {
        return """
            <!doctype html>
            <html lang="en"><head><meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Sample App Runtime</title>
            <style>
            :root { color-scheme: dark; font-family: Inter, ui-sans-serif, system-ui, sans-serif; }
            body { margin: 0; min-height: 100vh; background: #101820; color: #eef4f1; }
            main { width: min(980px, calc(100% - 32px)); margin: 0 auto; padding: 56px 0; }
            .eyebrow { color: #65d6b4; font-size: 12px; font-weight: 700; letter-spacing: .14em; text-transform: uppercase; }
            h1 { margin: 12px 0 8px; font-size: clamp(34px, 7vw, 68px); line-height: .98; }
            .intro { color: #a9bbb5; font-size: 18px; max-width: 650px; line-height: 1.6; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 14px; margin-top: 36px; }
            .item { padding: 20px; border: 1px solid #29433e; background: #15231f; border-radius: 8px; }
            .architecture .item { background: #182b35; border-color: #2b5562; }
            .label { color: #8ca59e; font-size: 12px; text-transform: uppercase; letter-spacing: .1em; }
            .value { margin-top: 10px; color: #fff; font: 600 16px ui-monospace, SFMono-Regular, Consolas, monospace; overflow-wrap: anywhere; }
            h2 { margin: 44px 0 14px; font-size: 22px; }
            .flow { margin-top: 36px; padding-top: 24px; border-top: 1px solid #29433e; color: #c6d5d0; line-height: 1.7; }
            .flow strong { color: #65d6b4; }
            </style></head><body><main>
            <div class="eyebrow">Sample application · live runtime</div>
            <h1>Running inside the cluster.</h1>
            <p class="intro">This page is served by the Java application pod currently handling your request.</p>
            <section class="grid" aria-label="Runtime details">__RUNTIME_CARDS__</section>
            <h2>Infrastructure</h2>
            <section class="grid architecture" aria-label="Infrastructure details">__INFRASTRUCTURE_CARDS__</section>
            <p class="flow"><strong>Request path:</strong> worker public IP -> NodePort 32621 -> sample-app Service -> application pod -> Spring Boot server.</p>
            </main></body></html>
            """;
        return template.replace("__RUNTIME_CARDS__", cards(runtime))
            .replace("__INFRASTRUCTURE_CARDS__", cards(infrastructure));
    }

    private String cards(Map<String, String> values) {
        StringBuilder cards = new StringBuilder();
        values.forEach((label, value) -> cards.append("<div class=\"item\"><div class=\"label\">")
            .append(label).append("</div><div class=\"value\">")
            .append(value).append("</div></div>"));
        return cards.toString();
    }
}
