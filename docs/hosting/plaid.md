# Setting Up Plaid

## 1. Create Your Plaid Account

Go to [https://dashboard.plaid.com](https://dashboard.plaid.com) and register for a new account.

---

## 2. Requesting Access Based on Your Bank Type

### For Banks That **Do Not Require OAuth**

1. On the Home page, find the section labeled "Learn how to build with Plaid" and click **Unlock real data**.
2. Enter your real name and phone number.
3. In the description box, write a statement such as:  
   This is for personal use only on a self-hosted version of the Maybe Finance software. I am only using it to manage my finances, sync my bank accounts, track my spending, and create a budget.
4. Leave the "Additional products" section **unchecked**.
5. Click **Request Access**.
6. Wait for your request to be approved (this may take more than 24 hours).

---

### For Banks That **Require OAuth**

1. In the left sidebar on the Plaid dashboard, click **Get production access**.
2. Enter your real address.
3. For the business profile, write:  
   This is for personal use only on a self-hosted version of the Maybe Finance software. I am only using it to manage my finances, sync my bank accounts, track my spending, and create a budget.
4. Leave the company website field **blank**.
5. Enter your real name, phone number, email address, and date of birth.
6. Click **Next**.
7. Indicate that you have 0 employees, specify your country of data access, confirm that you do not sell data, and confirm that you have not experienced a security breach in the past 12 months.
8. Click **Next**.
9. When asked "What industry are you in?", select **Budgeting and financial management tools**.
10. Click **Next**.
11. Enter any name for your application.
12. Upload the Maybe logo (must be 1024x1024px and under 4MB).
13. Leave the brand color as **#22CCEE**.
14. Set the Website URL to:  
    https://github.com/maybe-finance/maybe
15. In the "Reason for data access" box, enter:  
    This is for personal use only on a self-hosted version of the Maybe Finance software. I am only using it to manage my finances, sync my bank accounts, track my spending, and create a budget.
16. Enter your real email address as the support email.
17. Click **Next**.
18. For the "Where do you want to launch?" section, enter your country.
19. - In the "Payments" section, check only **Auth** and **Balance**. Leave the rest unchecked.
    - Leave all products in "Credit Underwriting" and "Fraud & Compliance" **unchecked**.
    - Check **all products** under the "Financial Management" section.
20. Click **Next**.
21. For use cases:
    - Select **Consumer bill pay** for the Payments section.
    - Select **Personal budgeting and financial advice** for all products in the Financial Management section.
22. Click **Next**.
23. Select the **Pay As You Go** plan.
24. Click **Next**.
25. Enter your billing details and check the agreement boxes.
26. Click **Next**.
27. Click **Start Security Practices Questionnaire**.
28. For each question, select **Other - please see comments**, then write in the notes:  
    This is for personal use only on a self-hosted version of the Maybe Finance software. I am only using it to manage my finances, sync my bank accounts, track my spending, and create a budget.
29. Click **Next**.
30. Repeat the process from step 28 for each new section of the questionnaire.
31. Continue clicking **Next** and repeating step 28 until the questionnaire is finished.
32. Click **Submit**.
33. Wait for approval (this may take more than 24 hours).

---

# Setting Up Maybe to Use Plaid

1. After your Plaid account is registered, go to [https://dashboard.plaid.com/developers/api](https://dashboard.plaid.com/developers/api) or click **Developers > API** in the sidebar, then click **Configure** next to Allowed redirect URIs.
2. Click **Add new URI**, type your domain, and add `/accounts` at the end (for example: `https://budget.yourdomain.com/accounts`).
3. Click **Save changes**.
4. Go to [https://dashboard.plaid.com/developers/keys](https://dashboard.plaid.com/developers/keys) or click **Developers > Keys** in the sidebar.
5. Copy your `client_id` and `secret` keys. Use the "Production" secret key.
6. In your `.env` file (next to your `docker-compose` file), add these lines:
```
   PLAID_CLIENT_ID: ENTER_CLIENT_ID_FROM_PLAID_HERE  
   PLAID_SECRET: ENTER_SECRET_KEY_FROM_PLAID_HERE  
   PLAID_ENV: production  # (use 'production' for Full/Limited Production Access, or 'sandbox' for Sandbox Access)
```
7. Restart Maybe.

---

Once you access your Maybe instance from your domain, you should now see the **Link account** option in the Maybe UI.
