package com.example;

import com.example.model.V1GitHubRepository;
import com.example.model.V1GitHubRepositoryList;
import io.kubernetes.client.extended.controller.Controller;
import io.kubernetes.client.extended.controller.builder.ControllerBuilder;
import io.kubernetes.client.extended.controller.builder.DefaultControllerBuilder;
import io.kubernetes.client.extended.controller.reconciler.Reconciler;
import io.kubernetes.client.informer.SharedIndexInformer;
import io.kubernetes.client.informer.SharedInformerFactory;
import io.kubernetes.client.openapi.ApiClient;
import io.kubernetes.client.util.generic.GenericKubernetesApi;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Configuration
public class ControllerConfiguration {

    @Bean
    GenericKubernetesApi<V1GitHubRepository, V1GitHubRepositoryList> gitHubRepositoryApi(ApiClient apiClient) {
        return new GenericKubernetesApi<>(V1GitHubRepository.class, V1GitHubRepositoryList.class, "timosalm.de", "v1", "githubrepositories", apiClient);
    }

    @Bean
    SharedIndexInformer<V1GitHubRepository> gitHubRepositorySharedIndexInformer(SharedInformerFactory sharedInformerFactory, GenericKubernetesApi<V1GitHubRepository, V1GitHubRepositoryList> api) {
        return sharedInformerFactory.sharedIndexInformerFor(api, V1GitHubRepository.class, 0);
    }

    @Bean
    public GitHubSourceReconciler reconciler(
            SharedIndexInformer<V1GitHubRepository> parentInformer, GenericKubernetesApi<V1GitHubRepository, V1GitHubRepositoryList> api, GitHubSourceApplicationService service) {
        return new GitHubSourceReconciler(parentInformer, api, service);
    }

    @Bean
    Controller controller(SharedInformerFactory sharedInformerFactory,
                          SharedIndexInformer<V1GitHubRepository> informer,
                          Reconciler reconciler) {
        DefaultControllerBuilder builder = ControllerBuilder
                .defaultBuilder(sharedInformerFactory)
                .watch(q -> ControllerBuilder
                        .controllerWatchBuilder(V1GitHubRepository.class, q)
                        .withResyncPeriod(Duration.ofSeconds(30))
                        .build())
                .withWorkerCount(2);
        return builder
                .withReconciler(reconciler)
                .withReadyFunc(informer::hasSynced)
                .withName("GitHubSourceControlller")
                .build();

    }

    @Bean
    ExecutorService executorService() {
        return Executors.newCachedThreadPool();
    }

    @Bean
    public CommandLineRunner commandLineRunner(SharedInformerFactory sharedInformerFactory, Controller controller) {
        return args -> Executors.newSingleThreadExecutor().execute(() -> {
            System.out.println("starting informers...");
            sharedInformerFactory.startAllRegisteredInformers();

            System.out.println("running controller..");
            controller.run();
        });
    }

}
