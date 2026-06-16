package com.acme.commons;

import org.springframework.stereotype.Component;

/**
 * Trivial shared component used by the Application Advisor custom-upgrades demo.
 *
 * Its only purpose is to be an "internal shared library that uses Spring", so that
 * Application Advisor blocks the consuming application's Spring Boot upgrade until a
 * custom upgrade mapping is provided for this library.
 */
@Component
public class GreetingProvider {

    public String greeting() {
        return "Hello from acme-spring-commons";
    }
}
