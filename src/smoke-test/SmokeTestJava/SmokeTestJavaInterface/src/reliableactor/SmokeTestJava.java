package reliableactor;

import java.util.concurrent.CompletableFuture;

import microsoft.servicefabric.actors.Actor;

public interface SmokeTestJava extends Actor {
	CompletableFuture<Integer> getCountAsync();

	CompletableFuture<?> setCountAsync(int count);
}
