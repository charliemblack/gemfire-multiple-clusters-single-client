package com.vmware.gemfire.demo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@NoArgsConstructor
@AllArgsConstructor
@Builder(toBuilder = true)
@Data
public class Customer implements Serializable {
    private static final long serialVersionUID = 42L;
    private String guid;
    private String firstName;
    private String middleName;
    private String lastName;
    private String email;
    private String username;
    private String password;
    private String telephoneNumber;
    private String dateOfBirth;
    private Integer age;
    private String companyEmail;
    private String nationalIdentityCardNumber;
    private String nationalIdentificationNumber;
    private String passportNumber;
}
