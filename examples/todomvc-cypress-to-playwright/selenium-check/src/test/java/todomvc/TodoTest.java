package todomvc;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;

import java.time.Duration;
import java.util.List;

import org.openqa.selenium.By;
import org.openqa.selenium.Keys;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

/** A Selenium suite for the TodoMVC app served at http://localhost:8888. */
public class TodoTest {

  static WebDriver driver;
  static TodoPage todo;

  @BeforeMethod
  public void setUp() {
    driver = new ChromeDriver();
    driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(5));
    driver.get("http://localhost:8888");
    todo = new TodoPage(driver);
  }

  @AfterMethod
  public void tearDown() {
    driver.quit();
  }

  @DataProvider(name = "titles")
  public Object[][] titles() {
    return new Object[][] {{"buy some cheese"}, {"feed the cat"}, {"  trims spaces  "}};
  }

  @Test(dataProvider = "titles", groups = {"smoke"})
  public void addsATodo(String title) {
    todo.add(title);
    todo.assertCount(1);
    assertEquals(driver.findElement(By.xpath("//ul[@class='todo-list']/li[1]//label")).getText(),
        title.trim());
  }

  @Test(groups = {"regression"})
  public void completesATodo() throws InterruptedException {
    todo.add("feed the cat");
    driver.findElement(By.cssSelector(".todo-list li:nth-child(1) .toggle")).click();
    Thread.sleep(500);
    assertTrue(driver.findElement(By.cssSelector(".todo-list li")).getAttribute("class")
        .contains("completed"));
    assertEquals(driver.findElement(By.className("todo-count")).getText(), "0 items left");
  }

  @Test(groups = {"regression"})
  public void editsATodoOnDoubleClick() {
    todo.add("book a doctors appointment");
    WebElement label = driver.findElement(By.cssSelector(".todo-list li label"));
    new Actions(driver).doubleClick(label).perform();
    WebElement edit = driver.findElement(By.cssSelector(".todo-list li .edit"));
    edit.sendKeys(Keys.chord(Keys.CONTROL, "a"), "book a dentist appointment", Keys.ENTER);
    new WebDriverWait(driver, Duration.ofSeconds(5))
        .until(ExpectedConditions.textToBe(By.cssSelector(".todo-list li label"),
            "book a dentist appointment"));
  }

  @Test(groups = {"regression"})
  public void filtersActiveTodos() {
    todo.add("one");
    todo.add("two");
    driver.findElements(By.cssSelector(".toggle")).get(0).click();
    driver.findElement(By.xpath("//ul[@class='filters']//a[text()='Active']")).click();
    List<WebElement> items = driver.findElements(By.cssSelector(".todo-list li"));
    assertEquals(items.size(), 1);
    assertEquals(items.get(0).getText(), "two");
  }

  @Test(groups = {"regression"})
  public void clearsCompletedTodos() {
    todo.add("one");
    todo.add("two");
    driver.findElements(By.cssSelector(".toggle")).get(1).click();
    driver.findElement(By.className("clear-completed")).click();
    todo.assertCount(1);
  }
}

/** Page object. */
class TodoPage {
  private final WebDriver driver;

  TodoPage(WebDriver driver) {
    this.driver = driver;
  }

  void add(String title) {
    WebElement input = driver.findElement(By.className("new-todo"));
    input.sendKeys(title);
    input.sendKeys(Keys.ENTER);
  }

  void assertCount(int n) {
    assertEquals(driver.findElements(By.cssSelector(".todo-list li")).size(), n);
  }
}
