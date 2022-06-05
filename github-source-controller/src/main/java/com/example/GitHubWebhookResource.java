package com.example;

import com.example.model.GitHubEvent;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GitHubWebhookResource {

    private static final Logger log = LoggerFactory.getLogger(GitHubWebhookResource.class);

    private final GitHubSourceApplicationService service;

    public GitHubWebhookResource(GitHubSourceApplicationService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<Void> addGitHubEvent(@NotNull @RequestBody GitHubEvent event) {
        log.info("New GitHubEvent received for " + event.getRepository().getCloneUrl() + "," + event.getBranch() + "," + event.getRevision());
        this.service.addGitHubEvent(event);
        return ResponseEntity.accepted().build();
    }
}
