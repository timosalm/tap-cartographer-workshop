package com.example.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class GitHubEvent {

    public GitHubEvent() {
    }

    private String ref;
    private HeadCommit headCommit;
    private Repository repository;

    public HeadCommit getHeadCommit() {
        return headCommit;
    }

    public Repository getRepository() {
        return repository;
    }

    public String getTarballUrl() {
        return repository.getHtmlUrl() + "/tarball/" + headCommit.getId();
    }

    public String getRevision() {
        return headCommit.getId();
    }

    public String getRef() {
        return ref;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public class HeadCommit {

        public HeadCommit() {
        }

        private String id;

        public String getId() {
            return id;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public class Repository {

        public Repository() {
        }

        private String cloneUrl;
        private String htmlUrl;

        public String getCloneUrl() {
            return cloneUrl;
        }

        public String getHtmlUrl() {
            return htmlUrl;
        }
    }
}
