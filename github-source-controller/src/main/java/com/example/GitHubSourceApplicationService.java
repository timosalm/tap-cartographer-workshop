package com.example;

import com.example.model.GitHubEvent;
import org.springframework.stereotype.Service;

import java.util.HashMap;

@Service
public class GitHubSourceApplicationService {

    private final HashMap<String, GitHubEvent> latestCommitMap = new HashMap<>();

    public void addGitHubEvent(GitHubEvent event) {
        String[] splittedRef = event.getRef().split("/");
        latestCommitMap.put(event.getRepository().getCloneUrl() + splittedRef[splittedRef.length - 1], event);
    }

    public GitHubEvent getLatestGithubEvent(String cloneUrl, String branch) {
        return latestCommitMap.get(cloneUrl + branch);
    }
}
