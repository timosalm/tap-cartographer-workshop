package com.example;

import com.example.model.GitHubEvent;
import org.jetbrains.annotations.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GitHubWebhookResource {

    private final GitHubSourceApplicationService service;

    public GitHubWebhookResource(GitHubSourceApplicationService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<Void> addGitHubEvent(@NotNull @RequestBody GitHubEvent event) {
        this.service.addGitHubEvent(event);
        return ResponseEntity.accepted().build();
    }
}
