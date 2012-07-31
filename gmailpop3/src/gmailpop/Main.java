package gmailpop;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

public class Main {

	static WebDriver driver;
	static WebDriverWait wait;

	private static void sleep(long millis) {
		try {
			Thread.sleep(millis);
		} catch (InterruptedException e) {
			System.err.println("Exception: " + e);
		}

	}

	private static WebElement waitForPresence(By by) {
		return wait.until(ExpectedConditions.presenceOfElementLocated(by));
	}

	private static void clickId(String id) {
		waitForPresence(By.id(id)).click();
	}

	public static void main(String[] args) {
		if (args.length != 3) {
			System.err.println("Usage: gmailpop datadir username passd_store");
			System.err.println("eg: gmailpop ~/.config/chromium myemail gnome");
			System.exit(1);
		}

		String datadir = args[0], username = args[1], passwd_store = args[2];

		ChromeOptions options = new ChromeOptions();
		options.addArguments("--user-data-dir=" + datadir);
		options.addArguments("--incognito");
		options.addArguments("--password-store=" + passwd_store);

		driver = new ChromeDriver(options);
		wait = new WebDriverWait(driver, 5);
		driver.get("https://gmail.com/");

		WebElement email = driver.findElement(By.id("Email"));
		email.clear();
		email.sendKeys(username);
		clickId("signIn");

		driver.switchTo().frame(waitForPresence(By.id("canvas_frame")));

		// open Settings drop down, click settings
		clickId(":pj");
		clickId(":pd");

		// Accounts and Import; By.linkText doesn't work
		waitForPresence(By.partialLinkText("Accounts and Import")).click();

		sleep(3 * 1000);
		// Check mail now; link missing for accounts currently checking email
		// Doesn't work for multiple POP3 accounts: hardly works for 1
		for (WebElement e : driver.findElements(By
				.cssSelector("td.CY span[role=\"link\"]"))) {
			if ("Check mail now".equals(e.getText())) {
				e.click();
				break;
			}
		}

		// Click on "Google" at the top left.
		// Clicking on "Inbox" leaves it highlighted until you move the mouse.
		clickId("gbqld");

		// driver.quit();
	}
}
